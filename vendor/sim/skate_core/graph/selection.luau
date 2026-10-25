-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    NodeId = {}
}

function t1.NodeId.eq(p1, p2) -- line: 20
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

t1.State = {}
t1.Transition = {}
t1.Topology = {}
t1.Selection = {}

local Selection = t1.Selection

function t1.Selection.next(p3, p4, p5) -- line: 50
    -- upvalues: Selection (copy)
    local current = p3.current

    if current == nil then
        return nil, (Selection.descend(p3, p3.root, 1, p5))
    end

    for i = 3, 0, -1 do
        local v1, v2 = Selection.search_transitions(p3, current, i, p5)

        if v1 ~= nil then
            return v1, v2
        end
    end

    local interruptibility = p3.graph.states[current + 1].interruptibility
    local v3

    if interruptibility == 0 and Selection.ancestors_active(p3, current, 2, p5) then
        v3 = current
    elseif interruptibility == 0 or interruptibility == 1 then
        v3 = Selection.descend(p3, p3.root, 2, p5)
    elseif interruptibility == 2 then
        local interrupt_ancestor = p3.graph.states[current + 1].interrupt_ancestor

        if interrupt_ancestor == nil then
            error("native processed interrupt ancestor must resolve", 0)
        end

        local v4 = Selection.ancestors_active(p3, interrupt_ancestor, 2, p5)
        local v5, v6

        if v4 then
            v5 = Selection.descend(p3, interrupt_ancestor, 2, p5)
            v6 = v5 == nil
        end

        if v4 and not v6 then
            return nil, v5
        end

        v3 = Selection.descend(p3, p3.root, 2, p5)
    else
        v3 = p4
    end

    return nil, v3
end

function t1.Selection.descend(p6, p7, p8, p9) -- line: 86
    -- upvalues: Selection (copy)
    local v7 = if p8 ~= 2 or not Selection.is_ancestor(p6, p7, p6.current) then 1 else 2

    if p9({
        tag = "State",
        p7
    }, v7) then
        return Selection.first_child_or_leaf(p6, p7, p8, p9)
    end

    return nil
end

function t1.Selection.first_child_or_leaf(p10, p11, p12, p13) -- line: 94
    -- upvalues: Selection (copy)
    local children = p10.graph.states[p11 + 1].children

    if #children == 0 then
        return p11
    end

    for _, v8 in ipairs(children) do
        local v9 = p10.graph.states[v8 + 1]

        if v9.enabled and v9.active then
            local v10 = Selection.descend(p10, v8, p12, p13)

            if v10 ~= nil then
                return v10
            end
        end
    end

    return nil
end

function t1.Selection.search_transitions(p14, p15, p16, p17) -- line: 113
    -- upvalues: Selection (copy)
    while true do
        for _, v12 in ipairs(p14.graph.states[p15 + 1].transitions) do
            local v13 = p14.graph.transitions[v12 + 1]
            local target = v13.target

            if v13.priority == p16 and v13.enabled and p14.graph.states[target + 1].enabled and p17({
                tag = "Transition",
                v12
            }, 1) and Selection.valid_target(p14, p14.current, target, p17) and p17({
                tag = "State",
                target
            }, 1) then
                local v14 = Selection.first_child_or_leaf(p14, target, 1, p17)

                if v14 ~= nil then
                    return v12, v14
                end
            end
        end

        p15 = p14.graph.states[p15 + 1].parent

        if p15 == nil then
            return nil, nil
        end
    end
end

function t1.Selection.valid_target(p18, p19, p20, p21) -- line: 147
    -- upvalues: Selection (copy)
    local v15 = p20

    while true do
        if v15 == nil then
            return true
        end

        if v15 == p20 or not Selection.is_ancestor(p18, v15, p19) then
            if not p21({
                tag = "State",
                v15
            }, 1) then
                return false
            end

            v15 = p18.graph.states[v15 + 1].parent
            continue
        end

        break
    end

    return Selection.ancestors_active(p18, v15, 2, p21)
end

function t1.Selection.ancestors_active(p22, p23, p24, p25) -- line: 163
    while p25({
        tag = "State",
        p23
    }, p24) do
        p23 = p22.graph.states[p23 + 1].parent

        if p23 == nil then
            return true
        end
    end

    return false
end

function t1.Selection.next_ids(p26, p27, p28) -- line: 185
    -- upvalues: Selection (copy)
    local current = p26.current

    if current == nil then
        return nil, (Selection.descend_ids(p26, p26.root, 1, p28))
    end

    for i = 3, 0, -1 do
        local v17, v18 = Selection.search_transitions_ids(p26, current, i, p28)

        if v17 ~= nil then
            return v17, v18
        end
    end

    local interruptibility = p26.graph.states[current + 1].interruptibility
    local v19

    if interruptibility == 0 and Selection.ancestors_active_ids(p26, current, 2, p28) then
        v19 = current
    elseif interruptibility == 0 or interruptibility == 1 then
        v19 = Selection.descend_ids(p26, p26.root, 2, p28)
    elseif interruptibility == 2 then
        local interrupt_ancestor = p26.graph.states[current + 1].interrupt_ancestor

        if interrupt_ancestor == nil then
            error("native processed interrupt ancestor must resolve", 0)
        end

        local v20 = Selection.ancestors_active_ids(p26, interrupt_ancestor, 2, p28)
        local v21, v22

        if v20 then
            v21 = Selection.descend_ids(p26, interrupt_ancestor, 2, p28)
            v22 = v21 == nil
        end

        if v20 and not v22 then
            return nil, v21
        end

        v19 = Selection.descend_ids(p26, p26.root, 2, p28)
    else
        v19 = p27
    end

    return nil, v19
end

function t1.Selection.descend_ids(p29, p30, p31, p32) -- line: 221
    -- upvalues: Selection (copy)
    if p32(true, p30, if p31 ~= 2 or not Selection.is_ancestor(p29, p30, p29.current) then 1 else 2) then
        return Selection.first_child_or_leaf_ids(p29, p30, p31, p32)
    end

    return nil
end

function t1.Selection.first_child_or_leaf_ids(p33, p34, p35, p36) -- line: 229
    -- upvalues: Selection (copy)
    local children = p33.graph.states[p34 + 1].children

    if #children == 0 then
        return p34
    end

    for _, v23 in ipairs(children) do
        local v24 = p33.graph.states[v23 + 1]

        if v24.enabled and v24.active then
            local v25 = Selection.descend_ids(p33, v23, p35, p36)

            if v25 ~= nil then
                return v25
            end
        end
    end

    return nil
end

function t1.Selection.search_transitions_ids(p37, p38, p39, p40) -- line: 248
    -- upvalues: Selection (copy)
    while true do
        for _, v27 in ipairs(p37.graph.states[p38 + 1].transitions) do
            local v28 = p37.graph.transitions[v27 + 1]
            local target = v28.target

            if v28.priority == p39 and v28.enabled and p37.graph.states[target + 1].enabled and p40(false, v27, 1) and Selection.valid_target_ids(p37, p37.current, target, p40) and p40(true, target, 1) then
                local v29 = Selection.first_child_or_leaf_ids(p37, target, 1, p40)

                if v29 ~= nil then
                    return v27, v29
                end
            end
        end

        p38 = p37.graph.states[p38 + 1].parent

        if p38 == nil then
            return nil, nil
        end
    end
end

function t1.Selection.valid_target_ids(p41, p42, p43, p44) -- line: 282
    -- upvalues: Selection (copy)
    local v30 = p43

    while true do
        if v30 == nil then
            return true
        end

        if v30 == p43 or not Selection.is_ancestor(p41, v30, p42) then
            if not p44(true, v30, 1) then
                return false
            end

            v30 = p41.graph.states[v30 + 1].parent
            continue
        end

        break
    end

    return Selection.ancestors_active_ids(p41, v30, 2, p44)
end

function t1.Selection.ancestors_active_ids(p45, p46, p47, p48) -- line: 298
    while p48(true, p46, p47) do
        p46 = p45.graph.states[p46 + 1].parent

        if p46 == nil then
            return true
        end
    end

    return false
end

function t1.Selection.is_ancestor(p49, p50, p51) -- line: 311
    while true do
        if p51 == nil then
            return false
        end

        if p51 == p50 then
            break
        end

        p51 = p49.graph.states[p51 + 1].parent
    end

    return true
end

return t1
