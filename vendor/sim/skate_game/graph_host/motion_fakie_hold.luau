-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t2 = {
    "Motion",
    "OnBoard",
    "OnGround",
    "RidingIdle",
    "Riding",
    "Turning",
    "Switch"
}
local t1 = {}

function t1.bind(p1) -- line: 17
    -- upvalues: rt (copy), t1 (copy), t2 (copy)
    local v1 = rt.filled(#p1.operations, false)

    for _, v2 in p1.transitions do
        local target = v2.target

        if target ~= nil then
            local t3 = {}

            while target ~= nil do
                table.insert(t3, p1.states[target + 1].name)
                target = p1.states[target + 1].parent
            end

            local v3 = 1
            local v4 = #t3

            while v3 < v4 do
                local v5 = t3[v4]
                local v6 = t3[v3]

                t3[v3] = v5
                t3[v4] = v6
                v3 += 1
                v4 -= 1
            end

            local v7 = #t3 == #t2

            if v7 then
                for i = 1, #t2 do
                    if t3[i] ~= t2[i] then
                        v7 = false
                        break
                    end
                end
            end

            if v7 then
                local expression = v2.expression

                if expression ~= nil then
                    t1.mark(p1, expression, v1)
                end
            end
        end
    end

    return v1
end

function t1.mark(p2, p3, p4) -- line: 60
    -- upvalues: t1 (copy)
    for _, v8 in p2.expressions[p3 + 1].children do
        if v8.tag == "Operation" and p2.operations[v8[1] + 1].name == "IsRidingFakie" then
            p4[v8[1] + 1] = true
        elseif v8.tag == "Expression" then
            t1.mark(p2, v8[1], p4)
        end
    end
end

function t1.blocked(p5, p6, p7) -- line: 70
    return p5 and p6[p7 + 1] == true
end

return t1
