-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    apply_filter = function(p1, p2) -- apply_filter | line: 12
        if p2 == 0 then
            return p1
        end

        if p2 == 1 then
            return p1 * -1
        end

        if p2 == 2 then
            return (math.abs(p1))
        end

        if p2 == 3 then
            if p1 >= 0 then
                return 1 - p1
            end

            return -1 - p1
        end

        if p2 == 4 then
            local v1 = if -p1 >= 0 then 0 else p1

            if 1 - v1 >= 0 then
                return v1
            end

            return 1
        end

        if p2 == 5 then
            if p1 >= 0 then
                return 3.1415927410125732 - p1
            end

            return -3.1415927410125732 - p1
        end

        if p2 == 6 then
            local v2 = p1 - 1.5707963705062866

            if v2 < -3.1415927410125732 then
                return v2 + 6.2831854820251465
            end

            return v2
        end

        local v3 = p1 + 1.5707963705062866

        if v3 > 3.1415927410125732 then
            return v3 - 6.2831854820251465
        end

        return v3
    end
}
local v4 = false

function t1.set_reference(p3) -- line: 65
    -- upvalues: v4 (ref)
    v4 = p3
end

function t1.filter_chain(p4, p5, p6) -- line: 68
    -- upvalues: t1 (copy), v4 (ref)
    if v4 then
        return t1.filter_chain_reference(p4, p5, p6)
    end

    local v5

    if p6 ~= nil then
        local v6 = p6[1]
        local v7 = p6[2]
        local apply_filter = t1.apply_filter
        local v8 = p5[1]
        local v9 = if v8 <= 7 then apply_filter(p4, v8) else p4
        local v10 = p5[2]

        v5 = if v10 <= 7 then apply_filter(v9, v10) else v9

        local v11 = p5[3]

        if v6 and v11 <= 7 then
            v5 = apply_filter(v5, v11)
        end

        local v12 = p5[4]

        if v7 and v12 <= 7 then
            v5 = apply_filter(v5, v12)
        end
    else
        v5 = p4
    end

    return v5
end

function t1.filter_chain_reference(p7, p8, p9) -- line: 95
    -- upvalues: t1 (copy)
    local v13 = p7

    if p9 ~= nil then
        local t2 = {
            true,
            true,
            p9[1],
            p9[2]
        }

        for i = 1, 4 do
            local v14 = p8[i]

            if t2[i] and v14 <= 7 then
                v13 = t1.apply_filter(v13, v14)
            end
        end
    end

    return v13
end

t1.IntentMutation = {}

function t1.IntentMutation.eq(p10, p11) -- line: 115
    if p10.tag ~= p11.tag then
        return false
    end

    if p10.tag == "Set" then
        return p10[1] == p11[1]
    end

    return true
end

t1.CreateMgIntent = {}

local v15 = table.freeze({
    tag = "Remove"
})
local v16 = table.freeze({
    tag = "None"
})

function t1.CreateMgIntent.emit(p12, p13, p14) -- line: 141
    -- upvalues: rt (copy), t1 (copy), v4 (ref), v15 (copy)
    local v17 = if p13 == nil then p12.default_value else p13

    if v17 == nil then
        if v4 then
            return {
                tag = "Remove"
            }
        end

        return v15
    end

    if v4 then
        return {
            tag = "Set",
            (t1.filter_chain(p12.scale * v17, rt.copy(p12.filters), p14))
        }
    end

    return {
        tag = "Set",
        (t1.filter_chain(p12.scale * v17, p12.filters, p14))
    }
end

function t1.CreateMgIntent.enter(p15, _, p17, p18) -- line: 162
    -- upvalues: t1 (copy)
    return t1.CreateMgIntent.emit(p15, p17, p18), true
end

function t1.CreateMgIntent.update(p19, p20, p21, p22) -- line: 171
    -- upvalues: t1 (copy), v4 (ref), v15 (copy), v16 (copy)
    return if p19.on_update then t1.CreateMgIntent.emit(p19, p21, p22)
        elseif p20 then if v4 then {
            tag = "None"
        } else v16
        elseif v4 then {
            tag = "Remove"
        }
        else v15, false
end

function t1.CreateMgIntent.exit(_) -- line: 185
    -- upvalues: v4 (ref), v15 (copy)
    if v4 then
        return {
            tag = "Remove"
        }
    end

    return v15
end

function t1.attach_intent(p24, p25, p26, p27) -- line: 192
    if p24 ~= nil then
        p26(p24)

        if p25 then
            p27(p24)
        end
    end
end

return t1
