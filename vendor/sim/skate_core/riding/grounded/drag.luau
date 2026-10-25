-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/riding/braking")
local t1 = {
    DRAG_FREQUENCY = 59.999996185302734,
    GroundDragInput = {}
}

function t1.GroundDragInput.calculate(p1, p2) -- line: 29
    -- upvalues: v1 (copy)
    return v1.calculate_linear_drag({
        flags_2468 = p1.flags_2468,
        absolute_body_speed = p1.absolute_body_speed_2616,
        balance_2720 = p1.balance_2720,
        scalar_2724 = p1.scalar_2724,
        comparison_scalar = p1.ground_normal_y
    }, p2)
end

t1.BodyInertias = {}
t1.DragSelection = {}
t1.DragBindingError = {}

function t1.BodyInertias.set_linear_drag(p3, p4, p5) -- line: 59
    -- upvalues: rt (copy), t1 (copy)
    local v2

    if p5.tag == "AllParts" then
        v2 = p3.part_inertia_indices
    else
        local v3 = p5[1]
        local v4 = v3 + 1

        if v4 > 18446744073709552000 then
            v4 = 18446744073709552000
        end

        if v3 <= v4 and v4 <= #p3.part_inertia_indices then
            v2 = rt.slice(p3.part_inertia_indices, v3, v4)
        end

        if v2 ~= nil and #v2 ~= 1 then
            v2 = nil
        end

        if v2 == nil then
            error("PartOutsideAssembly", 0)
        end
    end

    for i = 1, #v2 do
        if v2[i] >= #p3.inertias then
            error("InertiaOutsideStorage", 0)
        end
    end

    local v5 = rt.idiv(#v2, 4)

    for i = 0, v5 - 1 do
        local v6 = v2[i * 4 + 1]
        local v7 = v2[i * 4 + 2]
        local v8 = v2[i * 4 + 3]
        local v9 = v2[i * 4 + 4]
        local v10 = p4 * t1.DRAG_FREQUENCY

        p3.inertias[v6 + 1].linear_drag = v10
        p3.inertias[v7 + 1].linear_drag = v10
        p3.inertias[v8 + 1].linear_drag = v10
        p3.inertias[v9 + 1].linear_drag = v10
    end

    for i = v5 * 4 + 1, #v2 do
        local v11 = v2[i]

        p3.inertias[v11 + 1].linear_drag = p4 * t1.DRAG_FREQUENCY
    end
end

function t1.BodyInertias.apply_ground_drag(p6, p7) -- line: 110
    -- upvalues: t1 (copy)
    return t1.BodyInertias.set_linear_drag(p6, p7, {
        tag = "AllParts"
    })
end

return t1
