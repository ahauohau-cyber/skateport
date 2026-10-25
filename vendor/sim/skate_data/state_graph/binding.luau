-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_data/state_graph/attributes")
local Attributes, key_hash = v1.Attributes, v1.key_hash
local t1 = {
    Node = {}
}

function t1.Node.eq(p1, p2) -- line: 27
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

t1.State = {}
t1.Transition = {}
t1.Expression = {}
t1.OperationKind = {}
t1.Operation = {}
t1.Binding = {}
t1.OperationInstances = {}
t1.OperationFactory = {}

local function error_(p3, p4, p5) -- line: 79
    local v2 = p3.elements[p4 + 1]

    return string.format("Graph %s at byte %d: %s", v2.tag, v2.source_offset, p5)
end

function t1.Binding.from_graph(p6) -- line: 89
    -- upvalues: rt (copy), Attributes (copy), key_hash (copy), t1 (copy)
    local t2 = {
        root = 0,
        states = {},
        transitions = {},
        expressions = {},
        operations = {}
    }
    local v3 = #p6.elements
    local t3 = {}
    local t4 = {}

    for i = 0, v3 - 1 do
        local v4 = p6.elements[i + 1]

        for _, v5 in v4.children do
            if v5 <= i or v3 <= v5 then
                local _error = error
                local v6 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v6.tag, v6.source_offset, "invalid preorder ownership"), 0)
            end

            local v7 = t3[v5 + 1]

            t3[v5 + 1] = i

            if v7 ~= nil then
                local _error = error
                local v8 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v8.tag, v8.source_offset, "invalid preorder ownership"), 0)
            end
        end

        local v9 = t3[i + 1]
        local v10 = if v9 == nil then nil else t4[v9 + 1]
        local v11 = Attributes.new(v4.attributes)
        local v12 = if v10 == nil or t1.Binding.enabled(t2, v10) ~= 0 then Attributes.boolean_byte(v11, "enabled", 1) else 0
        local name = Attributes.text(v11, "name")

        if name == nil then
            name = "__unknown__"
        end

        local v13 = key_hash(v4.tag)

        if v13 == key_hash("state") then
            local v14

            if v10 ~= nil then
                if v10.tag == "State" then
                    v14 = v10[1]
                else
                    local _error = error
                    local v17 = p6.elements[i + 1]

                    _error(string.format("Graph %s at byte %d: %s", v17.tag, v17.source_offset, "state requires a state parent"), 0)
                end
            elseif i ~= 0 then
                if v10 ~= nil then
                    if v10.tag == "State" then
                        v14 = v10[1]
                    else
                        local _error = error
                        local v16 = p6.elements[i + 1]

                        _error(string.format("Graph %s at byte %d: %s", v16.tag, v16.source_offset, "state requires a state parent"), 0)
                    end
                else
                    local _error = error
                    local v15 = p6.elements[i + 1]

                    _error(string.format("Graph %s at byte %d: %s", v15.tag, v15.source_offset, "state requires a state parent"), 0)
                end
            end

            local interruptable = Attributes.text(v11, "interruptable")

            if interruptable == nil then
                interruptable = "true"
            end

            local v18 = if interruptable == "true" then 1 elseif interruptable == "false" then 0 else 2
            local v19 = #t2.states

            table.insert(t2.states, {
                expression = nil,
                interrupt_ancestor = nil,
                element = i,
                name = name,
                parent = v14,
                children = {},
                behaviors = {},
                transitions = {},
                enabled = v12,
                active = Attributes.boolean_byte(v11, "active", 1),
                interruptibility = v18
            })

            if v14 ~= nil then
                table.insert(t2.states[v14 + 1].children, v19)
            end

            local t6 = {
                tag = "State",
                v19
            }

            t4[i + 1] = t6
        elseif v13 == key_hash("transition") then
            if v10 == nil or v10.tag ~= "State" then
                local _error = error
                local v20 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v20.tag, v20.source_offset, "transition requires a state parent"), 0)
            end

            local v21 = v10[1]
            local v22 = #t2.transitions
            local priority = Attributes.text(v11, "priority")
            local v23 = if priority == "med" then 1
                elseif priority == "high" then 2
                elseif priority == "urgent" then 3
                else 0

            table.insert(t2.transitions, {
                target = nil,
                expression = nil,
                element = i,
                owner = v21,
                enabled = v12,
                priority = v23,
                hooks = {}
            })
            table.insert(t2.states[v21 + 1].transitions, v22)

            local t8 = {
                tag = "Transition",
                v22
            }

            t4[i + 1] = t8
        elseif v13 == key_hash("expression") then
            local v24 = #t2.expressions
            local op = Attributes.text(v11, "op")
            local v25 = if op == "and" then 1
                elseif op == "or" then 2
                elseif op == "not" then 3
                else 0

            table.insert(t2.expressions, {
                element = i,
                enabled = v12,
                operator = v25,
                children = {}
            })

            if v10 ~= nil and v10.tag == "State" then
                t2.states[v10[1] + 1].expression = v24
            elseif v10 ~= nil and v10.tag == "Transition" then
                t2.transitions[v10[1] + 1].expression = v24
            elseif v10 == nil or v10.tag ~= "Expression" then
                local _error = error
                local v26 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v26.tag, v26.source_offset, "expression requires state, transition or expression parent"), 0)
            else
                table.insert(t2.expressions[v10[1] + 1].children, {
                    tag = "Expression",
                    v24
                })
            end

            local t11 = {
                tag = "Expression",
                v24
            }

            t4[i + 1] = t11
        elseif v13 == key_hash("param") then
            if v10 == nil or v10.tag ~= "Operation" then
                local _error = error
                local v27 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v27.tag, v27.source_offset, "unbound parameter handler"), 0)
            end

            local v28 = v10[1]

            table.insert(t2.operations[v28 + 1].parameters, i)

            if #v4.children ~= 0 then
                local _error = error
                local v29 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v29.tag, v29.source_offset, "parameter children have no native object parent"), 0)
            end
        else
            local v30

            if v13 == key_hash("behaviour") then
                v30 = "Behavior"
            elseif v13 == key_hash("condition") then
                v30 = "Condition"
            elseif v13 == key_hash("hook") then
                v30 = "Hook"
            else
                local _error = error
                local v31 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v31.tag, v31.source_offset, "unsupported graph element"), 0)
            end

            if v10 == nil then
                local _error = error
                local v32 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v32.tag, v32.source_offset, "operation requires a parent"), 0)
            end

            local v33 = #t2.operations

            if v30 == "Behavior" and v10.tag == "State" then
                table.insert(t2.states[v10[1] + 1].behaviors, v33)
            elseif v30 == "Condition" and v10.tag == "Expression" then
                table.insert(t2.expressions[v10[1] + 1].children, {
                    tag = "Operation",
                    v33
                })
            elseif v30 ~= "Hook" or v10.tag ~= "Transition" then
                local _error = error
                local v34 = p6.elements[i + 1]

                _error(string.format("Graph %s at byte %d: %s", v34.tag, v34.source_offset, "unsupported operation parent"), 0)
            else
                table.insert(t2.transitions[v10[1] + 1].hooks, v33)
            end

            local v35 = if v30 == "Condition" then t1.parse_condition_mask(Attributes.text(v11, "mask")) else nil

            table.insert(t2.operations, {
                element = i,
                parent = rt.copy(v10),
                kind = v30,
                name = name,
                enabled = v12,
                condition_mask = v35,
                parameters = {}
            })

            local t14 = {
                tag = "Operation",
                v33
            }

            t4[i + 1] = t14
        end
    end

    if #t2.states == 0 then
        error("Graph has no root state", 0)
    end

    t1.Binding.process_names(t2, p6)

    return t2
end

function t1.Binding.instantiate_operations(p7, p8, p9) -- line: 293
    -- upvalues: rt (copy), Attributes (copy), t1 (copy)
    local v36 = table.create(#p7.operations)

    for _, v37 in p7.operations do
        local v38 = Attributes.new(p8.elements[v37.element + 1].attributes)
        local create = p9.create
        local kind = v37.kind
        local v39 = rt.copy(v37.parent)
        local ok, result = pcall(create, p9, kind, v39, v38)

        if not ok then
            error(t1.operation_error(p8, v37, (tostring(result))), 0)
        end

        if result == nil then
            error(t1.operation_error(p8, v37, "unregistered operation"), 0)
        end

        for _, v40 in v37.parameters do
            local v41 = Attributes.new(p8.elements[v40 + 1].attributes)
            local add_parameter = p9.add_parameter
            local ok, result2 = pcall(add_parameter, p9, result, v41)

            if not ok then
                error(t1.operation_error(p8, v37, (tostring(result2))), 0)
            end

            if result2 ~= nil then
                result = result2
            end
        end

        table.insert(v36, result)
    end

    return {
        operations = v36
    }
end

function t1.Binding.pack(p10) -- line: 328
    -- upvalues: import (copy)
    local packed = import("packed")
    local t15 = {}

    for _, v42 in { "states", "transitions", "expressions", "operations" } do
        if not packed.is_view(p10[v42]) then
            local v43 = packed.pack(p10[v42], {
                cache = 256
            })

            p10[v42] = packed.view(v43)
            t15[v42] = v43
        end
    end

    return t15
end

function t1.Binding.enabled(p11, p12) -- line: 342
    if p12.tag == "State" then
        return p11.states[p12[1] + 1].enabled
    end

    if p12.tag == "Transition" then
        return p11.transitions[p12[1] + 1].enabled
    end

    if p12.tag == "Expression" then
        return p11.expressions[p12[1] + 1].enabled
    end

    return p11.operations[p12[1] + 1].enabled
end

function t1.Binding.process_names(p13, p14) -- line: 355
    -- upvalues: Attributes (copy), t1 (copy)
    for i = 0, #p13.states - 1 do
        local v44 = p13.states[i + 1]

        if v44.interruptibility == 2 then
            local v45 = Attributes.new(p14.elements[v44.element + 1].attributes)
            local interruptable = Attributes.text(v45, "interruptable")

            if interruptable == nil then
                error("called `Option::unwrap()` on a `None` value", 0)
            end

            local v46 = t1.Binding.find_state(p13, i, interruptable, true)

            if v46 == nil then
                local _error = error
                local element = v44.element
                local v47 = p14.elements[element + 1]

                _error(string.format("Graph %s at byte %d: %s", v47.tag, v47.source_offset, "unresolved interrupt ancestor"), 0)
            end

            local v48 = i

            while v48 ~= nil and v48 ~= v46 do
                v48 = p13.states[v48 + 1].parent
            end

            if v48 == nil then
                local _error = error
                local element = v44.element
                local v49 = p14.elements[element + 1]

                _error(string.format("Graph %s at byte %d: %s", v49.tag, v49.source_offset, "interrupt target is not an ancestor"), 0)
            end

            p13.states[i + 1].interrupt_ancestor = v46
        end
    end

    for i = 0, #p13.transitions - 1 do
        local v50 = p13.transitions[i + 1]
        local v51 = Attributes.new(p14.elements[v50.element + 1].attributes)
        local target = Attributes.text(v51, "target")

        if target == nil then
            target = ""
        end

        local v52 = t1.Binding.find_state(p13, v50.owner, target, true)

        p13.transitions[i + 1].target = v52

        if v52 == nil or p13.states[v52 + 1].enabled == 0 then
            p13.transitions[i + 1].enabled = 0
        end
    end
end

function t1.Binding.find_state(p15, p16, p17, p18) -- line: 398
    -- upvalues: t1 (copy)
    local v53 = string.find(p17, ".", 1, true)

    if v53 == nil then
        local v54 = t1.name_hash(p17)
        local v55 = p16

        while true do
            for _, v56 in p15.states[v55 + 1].children do
                if t1.name_hash(p15.states[v56 + 1].name) == v54 then
                    return v56
                end
            end

            if not p18 then
                return nil
            end

            if t1.name_hash(p15.states[v55 + 1].name) == v54 then
                return v55
            end

            v55 = p15.states[v55 + 1].parent

            if v55 == nil then
                return nil
            end
        end
    end

    local v58 = string.sub(p17, 1, v53 - 1)
    local v60 = string.sub(p17, v53 + 1)
    local v61 = t1.Binding.find_state(p15, p16, v58, true)

    if v61 == nil then
        return nil
    end

    return t1.Binding.find_state(p15, v61, v60, false)
end

function t1.name_hash(p19) -- line: 434
    -- upvalues: rt (copy)
    local n1 = 2166136261

    for i = 1, #p19 do
        n1 = bit32.bxor(rt.wrapping_mul_u32(n1, 16777619), string.byte(p19, i))
    end

    return n1
end

function t1.parse_condition_mask(p20) -- line: 445
    if p20 == "sustain" then
        return 2
    end

    if p20 == "always" then
        return 3
    end

    if p20 == "postcond" then
        return 4
    end

    return 1
end

t1.error = error_

function t1.operation_error(p21, p22, p23) -- line: 461
    -- upvalues: t1 (copy), error_ (copy)
    return error_(p21, p22.element, string.format("%s `%s`: %s", t1.operation_kind(p22.kind), p22.name, p23))
end

function t1.operation_kind(p24) -- line: 470
    if p24 == "Behavior" then
        return "behaviour"
    end

    if p24 == "Condition" then
        return "condition"
    end

    return "hook"
end

return t1
