-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ActivationProgram = import("skate_core/graph/activation").ActivationProgram
local Selection = import("skate_core/graph/selection").Selection
local node_activation_typed = ActivationProgram.node_activation_typed
local t1 = {
    Behavior = {},
    Program = {},
    Frame = {},
    ActiveBehavior = {}
}

function t1.ActiveBehavior.eq(p1, p2) -- line: 51
    if p1.behavior == p2.behavior then
        return p1.instance == p2.instance
    end

    return false
end

t1.Host = {}
t1.Controller = {}

local Controller = t1.Controller

function t1.Controller.new(p3) -- line: 75
    return {
        frame = {
            dt = 0,
            current = nil,
            last = nil,
            state_times = table.create(p3)
        },
        active = {}
    }
end

function t1.Controller.update_reference(p4, p5, p6, p7) -- line: 88
    -- upvalues: ActivationProgram (copy), Selection (copy), Controller (copy)
    p4.frame.dt = p6

    local v1, v2 = Selection.next({
        graph = p5.topology,
        root = p5.root,
        current = p4.frame.current
    }, nil, function(p8, p9) -- line: 96
        -- upvalues: p4 (copy), p5 (copy), p7 (copy), ActivationProgram (copy)
        return ActivationProgram.node_activation(p5.activation, p8, p9, p4.frame, p7)
    end)
    local v3, v4 = Controller.prepare_lists_reference(p4, p5, v1, v2)
    local state_times = p4.frame.state_times

    for v5, v6 in state_times do
        state_times[v5] = v6 + p6
    end

    Controller.exit_reference(p4, p5, v3, p7)

    if v1 ~= nil then
        for _, v7 in ipairs(p5.transition_hooks[v1 + 1]) do
            p7.hook(p7, v7, p4.frame)
        end
    end

    Controller.enter(p4, p5, v4, p7)

    for _, v8 in ipairs(p4.active) do
        local v9 = p7.context(p7)

        v9[3] = v8.instance
        p7.update(p7, v8.behavior, v9, p4.frame)
    end
end

function t1.Controller.update(p10, p11, p12, p13) -- line: 124
    -- upvalues: ActivationProgram (copy), Selection (copy), Controller (copy)
    p10.frame.dt = p12

    local v10, v11 = Selection.next_ids({
        graph = p11.topology,
        root = p11.root,
        current = p10.frame.current
    }, nil, function(p14, p15, p16) -- line: 135
        -- upvalues: p10 (copy), p11 (copy), p13 (copy), ActivationProgram (copy)
        return ActivationProgram.node_activation_id(p11.activation, p14, p15, p16, p10.frame, p13)
    end)
    local v12, v13 = Controller.prepare_lists(p10, p11, v10, v11)
    local state_times = p10.frame.state_times

    for v14, v15 in state_times do
        state_times[v14] = v15 + p12
    end

    Controller.exit(p10, p11, v12, p13)

    if v10 ~= nil then
        for _, v16 in ipairs(p11.transition_hooks[v10 + 1]) do
            p13.hook(p13, v16, p10.frame)
        end
    end

    Controller.enter(p10, p11, v13, p13)

    for _, v17 in ipairs(p10.active) do
        local v18 = p13.context(p13)

        v18[3] = v17.instance
        p13.update(p13, v17.behavior, v18, p10.frame)
    end
end

function t1.Controller.update_typed(p17, p18, p19, p20, p21, p22, p23) -- line: 176
    -- upvalues: Selection (copy), node_activation_typed (copy), Controller (copy)
    p17.frame.dt = p19

    local v19, v20 = Selection.next_ids({
        graph = p18.topology,
        root = p18.root,
        current = p17.frame.current
    }, nil, function(p24, p25, p26) -- line: 187
        -- upvalues: p17 (copy), p18 (copy), p21 (copy), p22 (copy), node_activation_typed (copy)
        return node_activation_typed(p18.activation, p24, p25, p26, p17.frame, p21, p22)
    end)
    local v21, v22 = Controller.prepare_lists(p17, p18, v19, v20)
    local state_times = p17.frame.state_times

    for v23, v24 in state_times do
        state_times[v23] = v24 + p19
    end

    Controller.exit(p17, p18, v21, p20)

    if v19 ~= nil then
        for _, v25 in ipairs(p18.transition_hooks[v19 + 1]) do
            p20.hook(p20, v25, p17.frame)
        end
    end

    Controller.enter(p17, p18, v22, p20)

    for _, v26 in ipairs(p17.active) do
        p23[1] = 0
        p23[2] = 0
        p23[3] = 0
        p23[4] = 0
        p23[5] = 0
        p23[6] = 0
        p23[3] = v26.instance
        p21.update(p22, v26.behavior, p23, p17.frame)
    end
end

function t1.Controller.end_all_behaviors(p27, p28) -- line: 215
    -- upvalues: rt (copy)
    while #p27.active > 0 do
        local v27 = rt.copy(p27.active[#p27.active])
        local v28 = p28.context(p28)

        v28[3] = v27.instance
        p28["end"](p28, v27.behavior, v28, p27.frame)
        table.remove(p27.active)
        p28.release(p28, v27.instance)
    end
end

function t1.Controller.prepare_lists_reference(p29, p30, p31, p32) -- line: 229
    -- upvalues: rt (copy), t1 (copy)
    local v29 = t1.path(p30.topology, p29.frame.current)
    local target

    if p31 ~= nil then
        target = p30.topology.transitions[p31 + 1].target

        if table.find(v29, target) ~= nil then
            target = p30.topology.states[target + 1].parent
        end
    else
        target = p32
    end

    local v30 = t1.path(p30.topology, target)
    local n1 = 0

    for i = 1, math.min(#v29, #v30) do
        if v29[i] ~= v30[i] then
            break
        end

        n1 += 1
    end

    local v34 = rt.slice(v29, n1)
    local v35 = rt.slice(t1.path(p30.topology, p32), n1)

    p29.frame.last = p29.frame.current
    p29.frame.current = p32

    return v34, v35
end

local self = setmetatable({}, {
    __mode = "k"
})
local v37 = table.freeze({})

function t1.shared_path(p33, p34) -- line: 270
    -- upvalues: t1 (copy), self (copy), v37 (copy)
    if p34 == nil then
        return v37
    end

    local states = p33.states
    local v38 = self[states]

    if v38 == nil then
        v38 = {}
        self[states] = v38
    end

    local v39 = v38[p34]

    if v39 == nil then
        v39 = t1.path(p33, p34)
        v38[p34] = v39
    end

    return v39
end

function t1.Controller.prepare_lists(p35, p36, p37, p38) -- line: 289
    -- upvalues: rt (copy), t1 (copy), self (copy), v37 (copy)
    local topology = p36.topology
    local current = p35.frame.current
    local v40

    if current ~= nil then
        local states = topology.states
        local v41 = self[states]

        if v41 == nil then
            v41 = {}
            self[states] = v41
        end

        v40 = v41[current]

        if v40 == nil then
            v40 = t1.path(topology, current)
            v41[current] = v40
        end
    else
        v40 = v37
    end

    local target

    if p37 ~= nil then
        target = p36.topology.transitions[p37 + 1].target

        if table.find(v40, target) ~= nil then
            target = p36.topology.states[target + 1].parent
        end
    else
        target = p38
    end

    local topology2 = p36.topology
    local v42

    if target ~= nil then
        local states = topology2.states
        local v43 = self[states]

        if v43 == nil then
            v43 = {}
            self[states] = v43
        end

        v42 = v43[target]

        if v42 == nil then
            v42 = t1.path(topology2, target)
            v43[target] = v42
        end
    else
        v42 = v37
    end

    local n2 = 0

    for i = 1, math.min(#v40, #v42) do
        if v40[i] ~= v42[i] then
            break
        end

        n2 += 1
    end

    local v47 = rt.slice(v40, n2)
    local slice = rt.slice
    local topology3 = p36.topology
    local v48

    if p38 ~= nil then
        local states = topology3.states
        local v49 = self[states]

        if v49 == nil then
            v49 = {}
            self[states] = v49
        end

        v48 = v49[p38]

        if v48 == nil then
            v48 = t1.path(topology3, p38)
            v49[p38] = v48
        end
    else
        v48 = v37
    end

    local v50 = slice(v48, n2)

    p35.frame.last = p35.frame.current
    p35.frame.current = p38

    return v47, v50
end

function t1.Controller.exit_reference(p39, p40, p41, p42) -- line: 320
    -- upvalues: rt (copy)
    for i = #p39.active - 1, 0, -1 do
        local v51 = rt.copy(p39.active[i + 1])

        if table.find(p41, p40.behaviors[v51.behavior + 1].owner) ~= nil then
            local v52 = p42.context(p42)

            v52[3] = v51.instance
            p42["end"](p42, v51.behavior, v52, p39.frame)
            table.remove(p39.active, i + 1)
            p42.release(p42, v51.instance)
        end
    end

    for _, v53 in ipairs(p41) do
        p39.frame.state_times[v53 + 1] = nil
    end
end

function t1.Controller.exit(p43, p44, p45, p46) -- line: 341
    for i = #p43.active - 1, 0, -1 do
        local v54 = p43.active[i + 1]
        local behavior, instance = v54.behavior, v54.instance

        if table.find(p45, p44.behaviors[behavior + 1].owner) ~= nil then
            local v55 = p46.context(p46)

            v55[3] = instance
            p46["end"](p46, behavior, v55, p43.frame)
            table.remove(p43.active, i + 1)
            p46.release(p46, instance)
        end
    end

    for _, v56 in ipairs(p45) do
        p43.frame.state_times[v56 + 1] = nil
    end
end

function t1.Controller.enter(p47, p48, p49, p50) -- line: 363
    for _, v57 in ipairs(p49) do
        p47.frame.state_times[v57 + 1] = 0
    end

    for _, v58 in ipairs(p49) do
        for _, v59 in ipairs(p48.state_behaviors[v58 + 1]) do
            if p48.behaviors[v59 + 1].enabled then
                local v60 = p50.allocate(p50, v59, p47.frame)

                table.insert(p47.active, {
                    behavior = v59,
                    instance = v60
                })

                local v61 = p50.context(p50)

                v61[3] = v60
                p50.begin(p50, v59, v61, p47.frame)
            end
        end
    end
end

function t1.path(p51, p52) -- line: 381
    local t5 = {}
    local v62 = p52

    while v62 ~= nil do
        table.insert(t5, v62)
        v62 = p51.states[v62 + 1].parent
    end

    local v63 = #t5

    for i = 1, v63 // 2 do
        local v64 = v63 - i + 1
        local v65 = t5[v63 - i + 1]
        local v66 = t5[i]

        t5[i] = v65
        t5[v64] = v66
    end

    return t5
end

return t1
