-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    OrientationRandom = {}
}
local OrientationRandom = t1.OrientationRandom

function t1.OrientationRandom.new() -- line: 17
    return {
        words = { 0, 0, 4063039062, 2284922601, 3324304687, 117621916, 2654289789, 1876900708 }
    }
end

function t1.OrientationRandom.take_three(p1) -- line: 36
    -- upvalues: OrientationRandom (copy)
    return {
        OrientationRandom.next_u32(p1),
        OrientationRandom.next_u32(p1),
        (OrientationRandom.next_u32(p1))
    }
end

function t1.OrientationRandom.next_u32(p2) -- line: 43
    -- upvalues: rt (copy)
    local words = p2.words
    local v1 = words[8]
    local v2 = words[7]
    local v3 = rt.wrapping_add_u32(v2, v1)
    local v4 = if v3 < v1 or v3 < v2 then 1 else 0

    words[7] = v3

    for i = 5, 2, -1 do
        local v5 = words[i + 1]

        v3 = rt.wrapping_add_u32(rt.wrapping_add_u32(v5, v3), v4)
        v4 = if v3 < v5 then 1 else 0
        words[i + 1] = v3
    end

    words[8] = rt.wrapping_add_u32(v1, 1)

    if words[8] == 0 then
        for i = 6, 2, -1 do
            words[i + 1] = rt.wrapping_add_u32(words[i + 1], 1)

            if words[i + 1] ~= 0 then
                break
            end
        end
    end

    words[2] = rt.wrapping_add_u32(words[2], 1)

    return words[3]
end

return t1
