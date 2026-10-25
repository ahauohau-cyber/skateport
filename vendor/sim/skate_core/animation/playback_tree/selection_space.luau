-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local v1

local function PlaybackTree() -- line: 19
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v2
    end

    return v2
end

local t1 = {
    Parameter = {},
    Candidate = {},
    SelectionSpace = {}
}

function t1.SelectionSpace.new(p1, p2) -- line: 44
    local v3 = #p1 > 10 or #p2 == 0

    if not v3 then
        for _, v4 in ipairs(p2) do
            if #v4.values ~= #p1 then
                v3 = true
                break
            end
        end
    end

    if v3 then
        error("Invalid native selection space dimensions", 0)
    end

    return {
        selected = nil,
        speed = 1,
        requested_time = 0,
        parameters = p1,
        candidates = p2,
        values = {}
    }
end

function t1.SelectionSpace.current(p3) -- line: 69
    local selected = p3.selected

    return if selected ~= nil then p3.candidates[selected + 1].tree else nil
end

function t1.SelectionSpace.current_mut(p4) -- line: 78
    local selected = p4.selected

    return if selected ~= nil then p4.candidates[selected + 1].tree else nil
end

function t1.SelectionSpace.set_time(p5, p6) -- line: 86
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    p5.requested_time = p6

    local v5 = t1.SelectionSpace.current_mut(p5)

    if v5 == nil then
        return
    end

    local v6 = v1

    if v6 == nil then
        v6 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v6
    end

    v6.set_time(v5, p6)
end

function t1.SelectionSpace.set_speed(p7, p8) -- line: 94
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    p7.speed = p8

    local v7 = t1.SelectionSpace.current_mut(p7)

    if v7 == nil then
        return
    end

    local v8 = v1

    if v8 == nil then
        v8 = import("skate_core/animation/playback_tree").PlaybackTree
        v1 = v8
    end

    v8.set_speed(v7, p8)
end

function t1.SelectionSpace.select(p9, p10) -- line: 103
    -- upvalues: rt (copy), AttributeName (copy), t1 (copy)
    for _, v9 in ipairs(p10) do
        for v10, v11 in ipairs(p9.parameters) do
            if AttributeName.eq(v11.name, v9.name) then
                p9.values[v10] = v9.value
            end
        end
    end

    if p9.selected ~= nil then
        return
    end

    local v12 = table.create(#p9.parameters)

    for i = 0, #p9.parameters - 1 do
        local v13 = p9.values[i + 1]

        if v13 == nil then
            error(("SelectionSpace parameter %* has no source producer"):format(i), 0)
        end

        v12[i + 1] = v13
    end

    local v14 = rt.F32_MAX
    local v15

    for v16, v17 in ipairs(p9.candidates) do
        local v18 = v16 - 1
        local v19 = t1.distance(p9.parameters, v12, v17.values)

        if v19 < v14 then
            v15 = v18
            v14 = v19
        end
    end

    if v15 == nil then
        error("SelectionSpace has no finite native minimum", 0)
    end

    local v20

    for v21, v22 in ipairs(p9.candidates) do
        if v22.name == p9.candidates[v15 + 1].name then
            v20 = v21 - 1
            break
        end
    end

    p9.selected = v20
end

function t1.SelectionSpace.set_attributes(p11, p12) -- line: 148
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    t1.SelectionSpace.select(p11, p12)

    local speed = p11.speed
    local v23 = t1.SelectionSpace.current_mut(p11)

    if v23 ~= nil then
        local v24 = v1

        if v24 == nil then
            v24 = import("skate_core/animation/playback_tree").PlaybackTree
            v1 = v24
        end

        v24.set_attributes(v23, p12)

        local v25 = v1

        if v25 == nil then
            v25 = import("skate_core/animation/playback_tree").PlaybackTree
            v1 = v25
        end

        v25.set_speed(v23, speed)
    end

    return true
end

function t1.distance(p13, p14, p15) -- line: 161
    -- upvalues: rt (copy), t1 (copy)
    local v26 = rt.idiv(#p13, 2) * 2
    local v27 = v26 - 1
    local n1 = 0
    local n2 = 0

    for i = 0, v27, 2 do
        local v28 = t1.delta(p13[i + 1], p14[i + 1], p15[i + 1])

        n1 = p13[i + 1].weight * v28 * v28 + n1

        local v29 = t1.delta(p13[i + 2], p14[i + 2], p15[i + 2])

        n2 = p13[i + 2].weight * v29 * v29 + n2
    end

    local v30 = n2 + n1

    if v26 < #p13 then
        local v31 = t1.delta(p13[v26 + 1], p14[v26 + 1], p15[v26 + 1])

        return v30 + p13[v26 + 1].weight * v31 * v31
    end

    return v30 + 0
end

function t1.delta(p16, p17, p18) -- line: 180
    local v32 = p16.maximum - p16.minimum
    local v33, v34

    if v32 > 1.52587890625E-05 then
        v34 = p18 / v32
        v33 = p17 / v32
    else
        v33 = p17
        v34 = p18
    end

    if p16.mode == 1 and v34 < v33 then
        return 1 - v33 + v34
    end

    if p16.mode ~= 2 then
        return v34 - v33
    end

    local v36 = math.abs(v33 - v34)
    local v37 = 1 - v36

    if v36 - v37 >= 0 then
        return v37
    end

    return v36
end

return t1
