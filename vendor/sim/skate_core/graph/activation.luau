-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local evaluate_operator = require(sim.import)("skate_core/graph/expression").evaluate_operator
local t1 = {
    Child = {}
}

function t1.Child.eq(p1, p2) -- line: 27
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

t1.Expression = {}
t1.Condition = {}

function t1.Condition.eq(p3, p4) -- line: 44
    if p3.enabled == p4.enabled then
        return p3.mask == p4.mask
    end

    return false
end

t1.ActivationProgram = {}

local ActivationProgram = t1.ActivationProgram

t1.ConditionHost = {}

function t1.ActivationProgram.node_activation(p5, p6, p7, p8, p9) -- line: 64
    -- upvalues: ActivationProgram (copy)
    local v1 = if p6.tag == "State" then p5.state_expressions[p6[1] + 1] else p5.transition_expressions[p6[1] + 1]

    if v1 == nil then
        return true
    end

    local v2, v3 = ActivationProgram.expression_activation(p5, v1, p7, p8, 1, p9)

    if v3 == 0 then
        return bit32.band(v2, 255) ~= 0
    end

    return true
end

function t1.ActivationProgram.node_activation_id(p10, p11, p12, p13, p14, p15) -- line: 82
    -- upvalues: ActivationProgram (copy)
    local v4 = if p11 then p10.state_expressions[p12 + 1] else p10.transition_expressions[p12 + 1]

    if v4 == nil then
        return true
    end

    local v5, v6 = ActivationProgram.expression_activation(p10, v4, p13, p14, 1, p15)

    if v6 == 0 then
        return bit32.band(v5, 255) ~= 0
    end

    return true
end

function t1.ActivationProgram.expression_activation_reference(p16, p17, p18, p19, p20, p21) -- line: 99
    -- upvalues: evaluate_operator (copy), ActivationProgram (copy)
    local v7 = p16.expressions[p17 + 1]

    return evaluate_operator(v7.operator, #v7.children, p20, function(p22, p23) -- line: 112
        -- upvalues: p16 (copy), p18 (copy), p19 (copy), p21 (copy), v7 (copy), ActivationProgram (copy)
        local v9 = v7.children[p22 + 1]

        if v9.tag == "Expression" then
            return ActivationProgram.expression_activation(p16, v9[1], p18, p19, p23, p21)
        end

        return ActivationProgram.condition_activation(p16, v9[1], p18, p19, p23, p21)
    end)
end

function t1.ActivationProgram.expression_activation(p24, p25, p26, p27, p28, p29) -- line: 130
    -- upvalues: ActivationProgram (copy)
    local v10 = p24.expressions[p25 + 1]
    local operator, children = v10.operator, v10.children
    local v11 = #children

    if operator > 3 then
        return 1, p28
    end

    if operator == 3 then
        if not (v11 > 0) then
            error("stock NOT expression requires a child", 0)
        end

        local v12 = children[1]
        local v13, v14

        if v12.tag == "Expression" then
            v13, v14 = ActivationProgram.expression_activation(p24, v12[1], p26, p27, 1, p29)
        else
            v13, v14 = ActivationProgram.condition_activation(p24, v12[1], p26, p27, 1, p29)
        end

        local v15 = bit32.band(v13, 255)

        if v14 ~= 0 then
            return 1, v14
        end

        return if v15 == 0 then 1 else 0, v14
    end

    local v16 = operator == 2
    local v17 = if v16 then 0 else 1
    local v18 = v11 - 1
    local n1 = 1

    for i = 0, v18 do
        local v19 = if v16 then bit32.band(v17, 255) == 0 else nil

        if v16 and not v19 then
            break
        end

        local v20 = if not v16 then bit32.band(v17, 255) == 0 else nil

        if not v16 and v20 then
            break
        end

        local v21 = children[i + 1]
        local v22, v23

        if v21.tag == "Expression" then
            v22, v23 = ActivationProgram.expression_activation(p24, v21[1], p26, p27, 1, p29)
        else
            v22, v23 = ActivationProgram.condition_activation(p24, v21[1], p26, p27, 1, p29)
        end

        if v23 == 0 then
            v17 = if v16 then v22 else bit32.band(bit32.band(v22, 255), (bit32.band(v17, 255)))
            n1 = 0
        end
    end

    if n1 == 0 then
        return v17, n1
    end

    return 1, n1
end

local function expression_typed(p30, p31, p32, p33, p34, p35, p36) -- line: 212
    -- upvalues: expression_typed (copy)
    local v26 = p30.expressions[p31 + 1]
    local operator, children = v26.operator, v26.children
    local v27 = #children

    if operator > 3 then
        return 1, p34
    end

    if operator == 3 then
        if not (v27 > 0) then
            error("stock NOT expression requires a child", 0)
        end

        local v28 = children[1]
        local v29, v30

        if v28.tag == "Expression" then
            v29, v30 = expression_typed(p30, v28[1], p32, p33, 1, p35, p36)
        else
            local v31 = v28[1]
            local v32 = p30.conditions[v31 + 1]
            local enabled = v32.enabled
            local v33 = if enabled then bit32.band(v32.mask, p32) == 0 else nil

            if not enabled or v33 then
                v29 = 1
                v30 = 1
            else
                v29 = p35.condition_activation(p36, v31, p33)
                v30 = 0
            end
        end

        local v34 = bit32.band(v29, 255)

        if v30 ~= 0 then
            return 1, v30
        end

        return if v34 == 0 then 1 else 0, v30
    end

    local v35 = operator == 2
    local v36 = if v35 then 0 else 1
    local v37 = v27 - 1
    local n2 = 1

    for i = 0, v37 do
        local v38 = if v35 then bit32.band(v36, 255) == 0 else nil

        if v35 and not v38 then
            break
        end

        local v39 = if not v35 then bit32.band(v36, 255) == 0 else nil

        if not v35 and v39 then
            break
        end

        local v40 = children[i + 1]
        local v41, v42

        if v40.tag == "Expression" then
            v41, v42 = expression_typed(p30, v40[1], p32, p33, 1, p35, p36)
        else
            local v43 = v40[1]
            local v44 = p30.conditions[v43 + 1]
            local enabled = v44.enabled
            local v45 = if enabled then bit32.band(v44.mask, p32) == 0 else nil

            if not enabled or v45 then
                v41 = 1
                v42 = 1
            else
                v41 = p35.condition_activation(p36, v43, p33)
                v42 = 0
            end
        end

        if v42 == 0 then
            v36 = if v35 then v41 else bit32.band(bit32.band(v41, 255), (bit32.band(v36, 255)))
            n2 = 0
        end
    end

    if n2 == 0 then
        return v36, n2
    end

    return 1, n2
end

t1.ActivationProgram.expression_activation_typed = expression_typed

function t1.ActivationProgram.node_activation_typed(p37, p38, p39, p40, p41, p42, p43) -- line: 285
    -- upvalues: expression_typed (copy)
    local v48 = if p38 then p37.state_expressions[p39 + 1] else p37.transition_expressions[p39 + 1]

    if v48 == nil then
        return true
    end

    local v49, v50 = expression_typed(p37, v48, p40, p41, 1, p42, p43)

    if v50 == 0 then
        return bit32.band(v49, 255) ~= 0
    end

    return true
end

function t1.ActivationProgram.condition_activation(p44, p45, p46, p47, _, p49) -- line: 303
    local v51 = p44.conditions[p45 + 1]
    local enabled = v51.enabled
    local v52 = if enabled then bit32.band(v51.mask, p46) == 0 else nil

    if not enabled or v52 then
        return 1, 1
    end

    return p49.condition_activation(p49, p45, p47), 0
end

return t1
