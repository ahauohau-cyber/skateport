-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

function t1.encode_reference(p1) -- line: 18
    -- upvalues: rt (copy)
    local v1 = type(p1) == "string"
    local v2 = #p1

    local function byte_at(p2) -- line: 21
        -- upvalues: p1 (copy), v1 (copy)
        if v1 then
            return string.byte(p1, p2 + 1)
        end

        return p1[p2 + 1]
    end

    local t2 = {
        0, 0, 0, 0, 0
    }
    local n1 = 0

    while n1 < 30 and n1 < v2 do
        if (if v1 then string.byte(p1, n1 + 1) else p1[n1 + 1]) == 0 then
            break
        end

        local v6 = rt.idiv(n1, 6)
        local n2 = 79235168
        local n3 = 0

        while n3 < 6 and n1 < v2 do
            if (if v1 then string.byte(p1, n1 + 1) else p1[n1 + 1]) == 0 then
                break
            end

            local v9 = if v1 then string.byte(p1, n1 + 1) else p1[n1 + 1]
            local v11 = if v9 >= 128 then v9 - 256 else v9
            local v12 = if v11 >= 97 then v11 - 86
                elseif v11 > 90 then v11 - 58
                elseif v11 > 57 then v11 - 54
                else v11 - 47

            t2[v6 + 1] = rt.wrapping_add_u32(t2[v6 + 1], rt.wrapping_mul_u32(rt.to_u32(v12), n2))
            n2 = rt.idiv(n2, 38)
            n3 += 1
            n1 += 1
        end
    end

    return { t2 }
end

local t3 = {}
local n4 = 0

function t1.encode(p3) -- line: 73
    -- upvalues: t1 (copy), t3 (copy), n4 (ref)
    if type(p3) ~= "string" then
        return t1.encode_reference(p3)
    end

    local v13 = t3[p3]

    if v13 ~= nil then
        return {
            {
                v13[1],
                v13[2],
                v13[3],
                v13[4],
                v13[5]
            }
        }
    end

    local v14 = t1.encode_reference(p3)

    if not (n4 >= 4096) then
        local v15 = v14[1]

        t3[p3] = {
            v15[1],
            v15[2],
            v15[3],
            v15[4],
            v15[5]
        }
        n4 += 1
    end

    return v14
end

return t1
