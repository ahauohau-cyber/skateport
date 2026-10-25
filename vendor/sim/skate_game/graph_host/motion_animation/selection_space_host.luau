-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local PlaybackTransition = import("skate_core/animation/playback_transition").PlaybackTransition
local SelectionSpace = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
local t1 = {
    MotionAnimation = {}
}
local self = setmetatable({}, {
    __mode = "k"
})

local function is_static(p1) -- line: 35
    -- upvalues: self (copy), is_static (copy)
    if self[p1] then
        return true
    end

    local tag = p1.tag
    local v2

    if tag == "Clip" then
        v2 = true
    elseif tag == "PhaseBlend" or tag == "BlendSpace" then
        local v3 = p1[1]
        local children = if type(v3) == "table" then v3.children else nil

        if type(children) == "table" then
            v2 = true

            for _, v4 in children do
                if type(v4) ~= "table" or not is_static(v4) then
                    v2 = false
                    break
                end

                v2 = true
            end
        else
            v2 = false
        end
    else
        v2 = false

        if tag == "BindPose" then
            local motion = p1.motion

            if type(motion) == "table" then
                v2 = is_static(motion)
            end
        end
    end

    if v2 then
        self[p1] = true
    end

    return v2
end

t1.is_static = is_static

function t1.MotionAnimation.prepare_selection_spaces(p2, p3, p4) -- line: 73
    -- upvalues: PlaybackTransition (copy), SelectionSpace (copy), t1 (copy), is_static (copy)
    if is_static(p3) then
        return
    end

    local tag = p3.tag

    if tag == "SelectionSpace" then
        local v5 = p3[1]

        SelectionSpace.select(v5, p4)

        local v6 = SelectionSpace.current_mut(v5)

        if v6 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        t1.MotionAnimation.prepare_selection_spaces(p2, v6, p4)
    elseif tag == "BlendSpace" then
        local _ = p3[1]
    elseif tag == "PhaseBlend" then
        for _, v7 in p3[1].children do
            t1.MotionAnimation.prepare_selection_spaces(p2, v7, p4)
        end
    elseif tag == "Transition" then
        local v8 = p3[1]

        t1.MotionAnimation.prepare_selection_spaces(p2, v8.to, p4)

        if v8.settings.kind == 4 and not PlaybackTransition.complete(v8) then
            t1.MotionAnimation.prepare_selection_spaces(p2, v8.from, p4)
        end
    elseif tag == "BindPose" then
        t1.MotionAnimation.prepare_selection_spaces(p2, p3.motion, p4)
    end
end

local v9

v9 = function(p5, p6, p7) -- line: 117
    -- upvalues: v9 (ref), PlaybackTransition (copy), SelectionSpace (copy)
    local tag = p6.tag

    if tag == "SelectionSpace" then
        local v10 = p6[1]

        SelectionSpace.select(v10, p7)

        local v11 = SelectionSpace.current_mut(v10)

        if v11 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        v9(p5, v11, p7)
    elseif tag == "BlendSpace" then
        local _ = p6[1]
    elseif tag == "PhaseBlend" then
        for _, v12 in p6[1].children do
            v9(p5, v12, p7)
        end
    elseif tag == "Transition" then
        local v13 = p6[1]

        v9(p5, v13.to, p7)

        if v13.settings.kind == 4 and not PlaybackTransition.complete(v13) then
            v9(p5, v13.from, p7)
        end
    elseif tag == "BindPose" then
        v9(p5, p6.motion, p7)
    end
end

t1.MotionAnimation.prepare_selection_spaces_reference = v9

return t1
