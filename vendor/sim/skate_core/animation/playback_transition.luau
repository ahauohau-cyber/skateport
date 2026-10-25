-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1

local function PlaybackTree() -- line: 13
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v2
    end

    return v2
end

local t1 = {
    PlaybackTransition = {}
}

function t1.PlaybackTransition.new(p1, p2, p3) -- line: 33
    -- upvalues: rt (copy)
    return {
        elapsed = 0,
        sequence_complete = false,
        from = p1,
        to = p2,
        settings = rt.copy(p3)
    }
end

function t1.PlaybackTransition.complete(p4) -- line: 37
    if p4.settings.kind == 4 then
        return p4.sequence_complete
    end

    return p4.elapsed > p4.settings.seconds
end

function t1.PlaybackTransition.advance(p5, p6, p7, p8) -- line: 46
    -- upvalues: import (copy), v1 (ref)
    local v3 = v1

    if v3 == nil then
        v3 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v3
    end

    local t2 = {
        crossed_end = false,
        overshoot = -1,
        remaining_before_wrap = -1
    }

    if p5.settings.kind == 4 then
        if p5.sequence_complete then
            v3.advance(p5.to, p6, p7, p8)
        else
            v3.advance(p5.from, p6, p7, t2)

            if t2.crossed_end then
                p5.sequence_complete = true
                v3.advance(p5.to, t2.overshoot, p7, p8)
            else
                p8.crossed_end = false
                p8.remaining_before_wrap = v3.length(p5.to) + t2.remaining_before_wrap
            end
        end
    else
        if p5.settings.matching ~= 1 then
            v3.advance(p5.from, p6, p7, t2)
        end

        if p5.settings.matching == 3 then
            local v4 = v3.length(p5.to)
            local v5 = v3.time(p5.from)
            local set_time = v3.set_time
            local to = p5.to

            if not (v5 - v4 >= 0) then
                v4 = v5
            end

            set_time(to, v4)
        elseif p5.settings.matching ~= 2 or not (v3.length(p5.from) > 0) then
            v3.advance(p5.to, p6, p7, p8)
        else
            v3.set_time(p5.to, v3.length(p5.to) * (v3.time(p5.from) / v3.length(p5.from)))
        end

        p5.elapsed += p6
    end
end

function t1.PlaybackTransition.set_attributes(p9, p10) -- line: 80
    -- upvalues: import (copy), v1 (ref)
    local v6 = v1

    if v6 == nil then
        v6 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v6
    end

    local v7 = v6.set_attributes(p9.to, p10)

    if p9.settings.kind == 4 and not p9.sequence_complete then
        return v6.set_attributes(p9.from, p10)
    end

    return v7
end

function t1.PlaybackTransition.attributes_child(p11) -- line: 90
    if p11.settings.kind ~= 4 or p11.sequence_complete then
        return p11.to
    end

    return p11.from
end

function t1.PlaybackTransition.attributes(p12, p13) -- line: 98
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v8 = v1

    if v8 == nil then
        v8 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v8
    end

    return v8.attributes(t1.PlaybackTransition.attributes_child(p12), p13)
end

function t1.PlaybackTransition.query_attribute(p14, p15, p16, p17) -- line: 103
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v9 = v1

    if v9 == nil then
        v9 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v9
    end

    return v9.query_attribute(t1.PlaybackTransition.attributes_child(p14), p15, p16, p17)
end

function t1.PlaybackTransition.weight(p18) -- line: 107
    local v10 = p18.elapsed / p18.settings.seconds

    if -v10 >= 0 then
        v10 = 0
    end

    if not (1 - v10 >= 0) then
        v10 = 1
    end

    if p18.settings.seconds < 0.05000000074505806 or v10 > 1 or v10 < 0 then
        return v10
    end

    local v11 = v10 * v10
    local v12 = v11 * v10

    return v11 * 3 + -(v12 * 2)
end

function t1.PlaybackTransition.evaluate(p19, p20, p21, p22) -- line: 120
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v13 = v1

    if v13 == nil then
        v13 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v13
    end

    if p19.settings.kind == 4 then
        if p19.sequence_complete then
            return v13.evaluate(p19.to, p20, p21, p22)
        end

        return v13.evaluate(p19.from, p20, p21, p22)
    end

    local v14 = t1.PlaybackTransition.weight(p19)
    local v15 = v13.evaluate(p19.from, p20, p21, p22)
    local v16 = v13.evaluate(p19.to, p20, p21, p22)

    if p21 and v15 and v16 then
        if p19.settings.kind == 3 then
            table.insert(p22, {
                tag = "ChannelBlend",
                weight = v14,
                use_channels_from_weights = p19.settings.use_channels_from_weights
            })
        else
            table.insert(p22, {
                tag = "Blend",
                weight = v14
            })
        end
    end

    return v15 or v16
end

return t1
