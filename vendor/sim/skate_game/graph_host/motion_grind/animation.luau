-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local MotionGraphAttribute = require(sim.import)("skate_core/animation/output/attributes").MotionGraphAttribute
local t1 = {
    Animation = {},
    set = function(p2, p3, p4, p5) -- set | line: 36
        p2.set_attribute(p2, {
            sequence_id = -1,
            name = p3,
            value = p4,
            normalized = p5
        })
    end
}

function t1.endpoints(p6, p7) -- line: 46
    -- upvalues: rt (copy), v1 (copy), MotionGraphAttribute (copy), t1 (copy)
    local t2 = {
        0, 0
    }

    for i = 0, 1 do
        t1.set(p6, rt.copy(p7), i, true)
        p6.apply_parameters(p6)

        local v2 = MotionGraphAttribute.to_animation({
            value = 0,
            name = rt.copy(p7)
        })

        p6.query_current_attribute(p6, rt.copy(p7), 15, v2)

        local v3 = v2.payload[1][1]

        if v3 == nil then
            error("Grind twist query returned an uninitialized scalar", 0)
        end

        local v4 = i + 1

        buffer.writeu32(v1, 0, v3)
        t2[v4] = buffer.readf32(v1, 0)
    end

    return t2
end

return t1
