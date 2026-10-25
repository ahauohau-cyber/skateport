-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local StateGraph = import("skate_data/state_graph").StateGraph
local Binding = import("skate_data/state_graph/binding").Binding
local t1 = {
    GraphCompileError = {}
}

function t1.GraphCompileError.eq(p1, p2) -- line: 31
    if p1.tag ~= p2.tag then
        return false
    end

    if p1.tag == "UnresolvedTransitionTarget" then
        return p1.transition == p2.transition
    end

    if p1.tag == "InvalidOperationParent" then
        if p1.operation == p2.operation then
            return p1.expected == p2.expected
        end

        return false
    end

    if p1.tag == "InvalidStateBehavior" then
        if p1.state == p2.state then
            return p1.operation == p2.operation
        end

        return false
    end

    if p1.tag == "InvalidTransitionHook" then
        if p1.transition == p2.transition then
            return p1.operation == p2.operation
        end

        return false
    end

    if p1.tag ~= "InvalidExpressionChild" then
        return p1.operation == p2.operation
    end

    if p1.expression == p2.expression and p1.node.tag == p2.node.tag then
        return p1.node[1] == p2.node[1]
    end

    return false
end

function t1.GraphCompileError.fmt(p3) -- line: 52
    if p3.tag == "UnresolvedTransitionTarget" then
        return string.format("stock graph transition %d has no resolved target", p3.transition)
    end

    if p3.tag == "InvalidOperationParent" then
        return string.format("stock graph operation %d does not have its required %s parent", p3.operation, p3.expected)
    end

    if p3.tag == "InvalidStateBehavior" then
        return string.format("stock graph state %d references non-behavior operation %d", p3.state, p3.operation)
    end

    if p3.tag == "InvalidTransitionHook" then
        return string.format("stock graph transition %d references non-hook operation %d", p3.transition, p3.operation)
    end

    if p3.tag == "InvalidExpressionChild" then
        return string.format("stock graph expression %d has invalid child %s(%d)", p3.expression, p3.node.tag, p3.node[1])
    end

    return string.format("stock graph condition %d has no parsed TU3 mask", p3.operation)
end

t1.OperationRemap = {}

function t1.OperationRemap.eq(p4, p5) -- line: 94
    for _, v1 in ipairs({ "behaviors", "conditions", "hooks" }) do
        local v2 = p4[v1]
        local v3 = p5[v1]

        if #v2 ~= #v3 then
            return false
        end

        for i = 1, #v2 do
            if v2[i] ~= v3[i] then
                return false
            end
        end
    end

    return true
end

t1.CompiledGraph = {}

function t1.CompiledGraph.from_binding(p6) -- line: 115
    -- upvalues: rt (copy)
    local v4 = #p6.operations
    local v5 = table.create(v4)
    local v6 = table.create(v4)
    local v7 = table.create(v4)
    local t2 = {}
    local t3 = {}
    local t4 = {}

    for i = 0, v4 - 1 do
        local v8 = p6.operations[i + 1]

        if v8.kind == "Behavior" then
            v5[i + 1] = #t2
            table.insert(t2, i)
        elseif v8.kind == "Condition" then
            v6[i + 1] = #t3
            table.insert(t3, i)
        else
            v7[i + 1] = #t4
            table.insert(t4, i)
        end
    end

    local t5 = {
        states = {},
        transitions = {}
    }

    for v9, v10 in ipairs(p6.states) do
        t5.states[v9] = {
            parent = v10.parent,
            enabled = v10.enabled ~= 0,
            active = v10.active ~= 0,
            interruptibility = v10.interruptibility,
            interrupt_ancestor = v10.interrupt_ancestor,
            children = rt.copy(v10.children),
            transitions = rt.copy(v10.transitions)
        }
    end

    for i = 0, #p6.transitions - 1 do
        local v11 = p6.transitions[i + 1]
        local v12 = v11.enabled ~= 0
        local target = v11.target

        if target == nil then
            error({
                tag = "UnresolvedTransitionTarget",
                transition = i
            }, 0)
        end

        t5.transitions[i + 1] = {
            enabled = v12,
            target = target,
            priority = v11.priority
        }
    end

    local v13 = table.create(#t3)

    for v14, v15 in ipairs(t3) do
        local v16 = p6.operations[v15 + 1]
        local v17 = v16.enabled ~= 0
        local condition_mask = v16.condition_mask

        if condition_mask == nil then
            error({
                tag = "MissingConditionMask",
                operation = v15
            }, 0)
        end

        v13[v14] = {
            enabled = v17,
            mask = condition_mask
        }
    end

    local v18 = table.create(#p6.expressions)

    for i = 0, #p6.expressions - 1 do
        local v19 = p6.expressions[i + 1]
        local v20 = table.create(#v19.children)

        for v21, v22 in ipairs(v19.children) do
            if v22.tag == "Expression" then
                v20[v21] = {
                    tag = "Expression",
                    v22[1]
                }
            elseif v22.tag == "Operation" then
                local v23 = v6[v22[1] + 1]

                if v23 == nil then
                    error({
                        tag = "InvalidExpressionChild",
                        expression = i,
                        node = rt.copy(v22)
                    }, 0)
                end

                v20[v21] = {
                    tag = "Condition",
                    v23
                }
            else
                error({
                    tag = "InvalidExpressionChild",
                    expression = i,
                    node = rt.copy(v22)
                }, 0)
            end
        end

        v18[i + 1] = {
            operator = v19.operator,
            children = v20
        }
    end

    local v24 = table.create(#t2)

    for v25, v26 in ipairs(t2) do
        local v27 = p6.operations[v26 + 1]

        if v27.parent.tag ~= "State" then
            error({
                tag = "InvalidOperationParent",
                expected = "state",
                operation = v26
            }, 0)
        end

        v24[v25] = {
            owner = v27.parent[1],
            enabled = v27.enabled ~= 0
        }
    end

    local v28 = table.create(#p6.states)

    for i = 0, #p6.states - 1 do
        local v29 = p6.states[i + 1]
        local v30 = table.create(#v29.behaviors)

        for v31, v32 in ipairs(v29.behaviors) do
            local v33 = v5[v32 + 1]

            if v33 == nil then
                error({
                    tag = "InvalidStateBehavior",
                    state = i,
                    operation = v32
                }, 0)
            end

            v30[v31] = v33
        end

        v28[i + 1] = v30
    end

    local v34 = table.create(#p6.transitions)

    for i = 0, #p6.transitions - 1 do
        local v35 = p6.transitions[i + 1]
        local v36 = table.create(#v35.hooks)

        for v37, v38 in ipairs(v35.hooks) do
            local v39 = v7[v38 + 1]

            if v39 == nil then
                error({
                    tag = "InvalidTransitionHook",
                    transition = i,
                    operation = v38
                }, 0)
            end

            v36[v37] = v39
        end

        v34[i + 1] = v36
    end

    local v40 = table.create(#p6.states)

    for i = 1, #p6.states do
        v40[i] = p6.states[i].expression
    end

    local v41 = table.create(#p6.transitions)

    for i = 1, #p6.transitions do
        v41[i] = p6.transitions[i].expression
    end

    return {
        program = {
            topology = t5,
            root = p6.root,
            activation = {
                state_expressions = v40,
                transition_expressions = v41,
                expressions = v18,
                conditions = v13
            },
            behaviors = v24,
            state_behaviors = v28,
            transition_hooks = v34
        },
        operations = {
            behaviors = t2,
            conditions = t3,
            hooks = t4
        }
    }
end

t1.LoadedGraph = {}
t1.StockGraphs = {}

local function path_join(p7, p8) -- line: 295
    if p7 == nil or tostring(p7) == "" then
        return p8
    end

    local v42 = tostring(p7)
    local v43 = string.sub(v42, -1)

    if v43 == "/" or v43 == "\\" then
        return v42 .. p8
    end

    return v42 .. "/" .. p8
end

function t1.StockGraphs.load(p9, p10) -- line: 308
    -- upvalues: t1 (copy)
    return {
        action = t1.load_graph(p9, p10.action_graph),
        motion = t1.load_graph(p9, p10.motion_graph)
    }
end

function t1.load_graph(p11, p12) -- line: 320
    -- upvalues: StateGraph (copy), Binding (copy), t1 (copy)
    local v44

    if p11 == nil or tostring(p11) == "" then
        v44 = p12
    else
        local v45 = tostring(p11)
        local v46 = string.sub(v45, -1)

        v44 = if v46 == "/" or v46 == "\\" then v45 .. p12 else v45 .. "/" .. p12
    end

    local v47 = StateGraph.load(v44)
    local v48 = Binding.from_graph(v47)
    local from_binding = t1.CompiledGraph.from_binding
    local ok, result = pcall(from_binding, v48)

    if not ok then
        local v49 = if type(result) ~= "table" then tostring(result) elseif result.tag == nil then tostring(result) else t1.GraphCompileError.fmt(result)

        error(string.format("Invalid runtime graph %s: %s", v44, v49), 0)
    end

    return {
        source = v47,
        binding = v48,
        runtime = result
    }
end

return t1
